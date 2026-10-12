FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY admin/VeroEqulibraFit.Admin/VeroEqulibraFit.Admin.csproj admin/VeroEqulibraFit.Admin/
RUN dotnet restore admin/VeroEqulibraFit.Admin/VeroEqulibraFit.Admin.csproj
COPY admin/ admin/
RUN dotnet publish admin/VeroEqulibraFit.Admin/VeroEqulibraFit.Admin.csproj -c Release --no-restore -o /app/publish
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app/publish .
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["dotnet", "VeroEqulibraFit.Admin.dll"]
