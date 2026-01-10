variable "yc_token" {
  description = "OAuth-токен яндекса"
  type        = string
  sensitive   = true # Чтобы не светился в логах
}

variable "yc_folder_id" {
  description = "ID папки в облаке"
  type        = string
  default     = "b1g1lgl2fvqafcbaod3g" # Твой ID
}

variable "yc_zone" {
  description = "Зона доступности"
  default     = "ru-central1-a"
}

variable "db_password" {
  description = "Пароль для базы данных PostgreSQL"
  type        = string
  sensitive   = true
}