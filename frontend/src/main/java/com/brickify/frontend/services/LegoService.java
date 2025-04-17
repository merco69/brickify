package com.brickify.frontend.services;

import com.brickify.frontend.api.ApiClient;
import com.brickify.frontend.models.LegoPart;
import java.io.IOException;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;

public class LegoService {
    
    public List<LegoPart> getAllParts() {
        try {
            LegoPart[] parts = ApiClient.get("/api/lego/parts", LegoPart[].class);
            return Arrays.asList(parts);
        } catch (IOException e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
    
    public LegoPart getPartById(String id) {
        try {
            return ApiClient.get("/api/lego/parts/" + id, LegoPart.class);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    public List<LegoPart> searchParts(String query) {
        try {
            LegoPart[] parts = ApiClient.get("/api/lego/parts/search?q=" + query, LegoPart[].class);
            return Arrays.asList(parts);
        } catch (IOException e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
    
    public List<LegoPart> getPartsByCategory(String category) {
        try {
            LegoPart[] parts = ApiClient.get("/api/lego/parts/category/" + category, LegoPart[].class);
            return Arrays.asList(parts);
        } catch (IOException e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
    
    public List<String> getAllCategories() {
        try {
            String[] categories = ApiClient.get("/api/lego/categories", String[].class);
            return Arrays.asList(categories);
        } catch (IOException e) {
            e.printStackTrace();
            return new ArrayList<>();
        }
    }
} 