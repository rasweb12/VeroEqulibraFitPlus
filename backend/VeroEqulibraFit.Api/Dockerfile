FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY backend/VeroEqulibraFit.Domain/VeroEqulibraFit.Domain.csproj backend/VeroEqulibraFit.Domain/
COPY backend/VeroEqulibraFit.Contracts/VeroEqulibraFit.Contracts.csproj backend/VeroEqulibraFit.Contracts/
COPY backend/VeroEqulibraFit.Application/VeroEqulibraFit.Application.csproj backend/VeroEqulibraFit.Application/
COPY backend/VeroEqulibraFit.Infrastructure/VeroEqulibraFit.Infrastructure.csproj backend/VeroEqulibraFit.Infrastructure/
COPY backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj backend/VeroEqulibraFit.Api/
RUN dotnet restore backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj
COPY backend/ backend/
RUN dotnet publish backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj -c Release --no-restore -o /app/publish
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "VeroEqulibraFit.Api.dll"]
