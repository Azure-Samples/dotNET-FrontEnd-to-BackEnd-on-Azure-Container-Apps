#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["Store.ProductApi/Store.ProductApi.csproj", "Store.ProductApi/"]
COPY ["Monitoring/Monitoring.csproj", "Monitoring/"]
RUN dotnet restore "Store.ProductApi/Store.ProductApi.csproj"
COPY . .
WORKDIR "/src/Store.ProductApi"
RUN dotnet build "Store.ProductApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Store.ProductApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Store.ProductApi.dll"]