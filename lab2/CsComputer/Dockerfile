# Stage 1: use the full SDK image to compile the project.
# This image is large (~800MB) but only used during build — it never ships.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the project file first and restore NuGet packages.
# Docker caches this layer separately, so if only Program.cs changes,
# the restore step is skipped on the next build — saves time.
COPY CsComputer.csproj ./
RUN dotnet restore

# Now copy the rest of the source and compile a Release build.
COPY . ./
RUN dotnet publish -c Release -o /app/publish

# Stage 2: use the slim runtime image (~200MB) to actually run the app.
# We copy only the compiled output from Stage 1 — no SDK, no source code.
FROM mcr.microsoft.com/dotnet/runtime:8.0
WORKDIR /app
COPY --from=build /app/publish .

# dotnet runs the compiled DLL — not the .cs source file.
ENTRYPOINT ["dotnet", "CsComputer.dll"]