package com.brickify.frontend.models;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LegoPart {
    private String id;
    private String name;
    private String category;
    private String color;
    private String imageUrl;
    private int quantity;
    private double price;
    private String dimensions;
    private String description;
} 