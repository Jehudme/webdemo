module org.example.webdemoclient {
    requires javafx.controls;
    requires javafx.fxml;
    requires jpro.webapi;

    exports org.example.webdemoclient;
    opens org.example.webdemoclient to javafx.graphics, javafx.fxml, jpro.webapi;
}