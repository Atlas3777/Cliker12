# === 1. Сеть ===
resource "yandex_vpc_network" "clicker_net" {
  name = "clicker-network"
}

resource "yandex_vpc_subnet" "clicker_subnet" {
  name           = "clicker-subnet-a"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.clicker_net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# === 2. Сервисный аккаунт (SA) ===
# Нужен, чтобы приложение могло ходить в S3 и чтобы пушить образы
resource "yandex_iam_service_account" "sa" {
  name        = "clicker-sa"
  description = "Service account for Clicker App"
}

# Права: Редактор в папке (чтобы мог читать/писать везде)
resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Права: Вызывать контейнеры (нужно для Serverless)
resource "yandex_resourcemanager_folder_iam_member" "sa_invoker" {
  folder_id = var.yc_folder_id
  role      = "serverless.containers.invoker"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Права: Загружать образы в реестр
resource "yandex_resourcemanager_folder_iam_member" "sa_pusher" {
  folder_id = var.yc_folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage_editor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# === 3. Container Registry (Реестр образов) ===
# Сюда мы будем пушить Docker-образ
resource "yandex_container_registry" "registry" {
  name      = "clicker-registry"
  folder_id = var.yc_folder_id
}

# === 4. Object Storage (S3 для картинок) ===
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static key for Object Storage"
}

resource "yandex_storage_bucket" "assets" {
  # Добавляем явное указание папки!
  folder_id = var.yc_folder_id 
  
  bucket = "clicker-assets-${substr(yandex_iam_service_account.sa.id, 0, 8)}"
  acl    = "public-read"
}

# === 5. PostgreSQL (База данных) ===
resource "yandex_mdb_postgresql_cluster" "pg_cluster" {
  name        = "clicker-postgres"
  environment = "PRESTABLE" # Дешевле
  network_id  = yandex_vpc_network.clicker_net.id

  config {
    version = 15
    resources {
      # b1.medium - это burstable (дешевый), но достаточно мощный для старта
      resource_preset_id = "b1.medium" 
      disk_type_id       = "network-hdd"
      disk_size          = 10
    }
  }

  database {
    name  = "clickerdb"
    owner = "clickeruser"
  }

  user {
    name     = "clickeruser"
    password = var.db_password
    permission {
      database_name = "clickerdb"
    }
  }

  host {
    zone      = var.yc_zone
    subnet_id = yandex_vpc_subnet.clicker_subnet.id
    assign_public_ip = true # Оставим True, чтобы ты мог подключиться из дома для тестов
  }
}

# === OUTPUTS (Что мы получим в консоль после установки) ===

output "registry_id" {
  value = yandex_container_registry.registry.id
}

output "db_host_public" {
  value = "c-${yandex_mdb_postgresql_cluster.pg_cluster.id}.rw.mdb.yandexcloud.net"
}

output "s3_bucket" {
  value = yandex_storage_bucket.assets.bucket
}

output "s3_access_key" {
  value = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive = true
}

output "s3_secret_key" {
  value = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  sensitive = true
}

# === 6. Виртуальная машина с Docker (COI) ===

# Получаем ID последнего образа с Docker
data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "clicker_vm" {
  name        = "clicker-vm"
  platform_id = "standard-v3" # Самые современные и эффективные ядра
  zone        = var.yc_zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20 # Экономим: 20% гарантированной мощности (хватит для кликера)
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container_optimized_image.id
      size     = 15
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.clicker_subnet.id
    nat       = true # Включаем публичный IP
  }

  service_account_id = yandex_iam_service_account.sa.id

  metadata = {
      ssh-keys = "artem:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL6BFSvU6sGCNrt7/yOmlyj5qIdoIb3lWmt7mPwu/dmK artem@DESKTOP-SNP8QAV"
      docker-container-declaration = <<-EOT
        spec:
          containers:
          - name: clicker-web
            image: cr.yandex/${yandex_container_registry.registry.id}/clicker-web:v5
            ports:
              - containerPort: 8080
                hostPort: 8080
            securityContext:
              privileged: false
            env:
              - name: YandexCloud__BucketName
                value: ${yandex_storage_bucket.assets.bucket}
              - name: AWS__Region
                value: ru-central1
              - name: AWS__ServiceURL
                value: https://s3.yandexcloud.net
              - name: AWS__AccessKey
                value: "${yandex_iam_service_account_static_access_key.sa_static_key.access_key}"
              - name: AWS__SecretKey
                value: "${yandex_iam_service_account_static_access_key.sa_static_key.secret_key}"
              - name: ConnectionStrings__DefaultConnection
                value: "Host=c-${yandex_mdb_postgresql_cluster.pg_cluster.id}.rw.mdb.yandexcloud.net;Port=6432;Database=clickerdb;Username=clickeruser;Password=${var.db_password};SSL Mode=Require;Trust Server Certificate=true"
            volumeMounts:
              - name: dp-keys
                mountPath: /root/.aspnet/DataProtection-Keys
            stdin: false
            tty: false
          volumes:
            - name: dp-keys
              hostPath:
                path: /home/artem/aspnet-keys
      EOT
    }
}

# === 7. Обновленные Output ===

output "vm_public_ip" {
  description = "IP адрес твоего сайта"
  value       = yandex_compute_instance.clicker_vm.network_interface.0.nat_ip_address
}

# output "game_url" {
#   value = yandex_serverless_container.clicker_app.url
# }
# === 7. Делаем контейнер публичным ===
# resource "yandex_serverless_container_iam_binding" "clicker_public_access" {
#   container_id = yandex_serverless_container.clicker_app.id
#   role         = "serverless.containers.invoker"
#   
#   members = [
#     "system:allUsers",
#   ]
# }