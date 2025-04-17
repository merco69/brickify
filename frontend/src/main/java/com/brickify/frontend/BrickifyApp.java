package com.brickify.frontend;

import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.stage.Stage;

public class BrickifyApp extends Application {
    
    @Override
    public void start(Stage primaryStage) throws Exception {
        FXMLLoader loader = new FXMLLoader(getClass().getResource("/fxml/main.fxml"));
        Parent root = loader.load();
        
        Scene scene = new Scene(root);
        scene.getStylesheets().add(getClass().getResource("/styles/main.css").toExternalForm());
        
        primaryStage.setTitle("Brickify - Éditeur de modèles LEGO");
        primaryStage.setScene(scene);
        primaryStage.setMinWidth(1024);
        primaryStage.setMinHeight(768);
        primaryStage.show();
    }
    
    public static void main(String[] args) {
        launch(args);
    }
} 