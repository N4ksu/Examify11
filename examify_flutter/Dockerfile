# Stage 1: Build the Flutter Web app
FROM instrumentisto/flutter:3.16 AS build

# Set working directory
WORKDIR /app

# Copy the pubspec and other necessary files
COPY pubspec.yaml pubspec.lock ./

# Get the dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the web application
RUN flutter build web --release

# Stage 2: Serve the app with Nginx
FROM nginx:alpine

# Copy the build output from the previous stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
