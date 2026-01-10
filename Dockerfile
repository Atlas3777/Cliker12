# Используем официальный образ .NET 8 SDK для сборки
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Копируем csproj и восстанавливаем зависимости
COPY ["CSharpClicker.Web.csproj", "./"]
RUN dotnet restore "CSharpClicker.Web.csproj"

# Копируем всё остальное и собираем
COPY . .
RUN dotnet build "CSharpClicker.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "CSharpClicker.Web.csproj" -c Release -o /app/publish

# Финальный образ для запуска
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Устанавливаем порт для Yandex Serverless Containers (обычно требует 8080)
ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "CSharpClicker.Web.dll"]