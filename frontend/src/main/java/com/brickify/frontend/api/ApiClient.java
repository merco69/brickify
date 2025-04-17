package com.brickify.frontend.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import okhttp3.*;
import java.io.IOException;
import java.util.concurrent.TimeUnit;

public class ApiClient {
    private static final String BASE_URL = System.getenv().getOrDefault("BACKEND_URL", "http://localhost:8080");
    private static final OkHttpClient client = new OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .build();
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final MediaType JSON = MediaType.parse("application/json; charset=utf-8");

    public static <T> T get(String endpoint, Class<T> responseType) throws IOException {
        Request request = new Request.Builder()
                .url(BASE_URL + endpoint)
                .get()
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected response code: " + response.code());
            }
            String responseBody = response.body().string();
            return objectMapper.readValue(responseBody, responseType);
        }
    }

    public static <T> T post(String endpoint, Object requestBody, Class<T> responseType) throws IOException {
        String jsonBody = objectMapper.writeValueAsString(requestBody);
        RequestBody body = RequestBody.create(jsonBody, JSON);
        
        Request request = new Request.Builder()
                .url(BASE_URL + endpoint)
                .post(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected response code: " + response.code());
            }
            String responseBody = response.body().string();
            return objectMapper.readValue(responseBody, responseType);
        }
    }

    public static <T> T put(String endpoint, Object requestBody, Class<T> responseType) throws IOException {
        String jsonBody = objectMapper.writeValueAsString(requestBody);
        RequestBody body = RequestBody.create(jsonBody, JSON);
        
        Request request = new Request.Builder()
                .url(BASE_URL + endpoint)
                .put(body)
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected response code: " + response.code());
            }
            String responseBody = response.body().string();
            return objectMapper.readValue(responseBody, responseType);
        }
    }

    public static void delete(String endpoint) throws IOException {
        Request request = new Request.Builder()
                .url(BASE_URL + endpoint)
                .delete()
                .build();

        try (Response response = client.newCall(request).execute()) {
            if (!response.isSuccessful()) {
                throw new IOException("Unexpected response code: " + response.code());
            }
        }
    }
} 