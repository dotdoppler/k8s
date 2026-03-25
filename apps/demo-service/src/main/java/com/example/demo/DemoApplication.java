package com.example.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.beans.factory.annotation.Value;

import java.net.InetAddress;
import java.net.UnknownHostException;

@SpringBootApplication
@RestController
public class DemoApplication {

    @Value("${app.message:No Message Found}")
    private String customMessage;

    public static void main(String[] args) {
        SpringApplication.run(DemoApplication.class, args);
    }

    @GetMapping("/hello")
    public String hello() {
        try {
            String podName = InetAddress.getLocalHost().getHostName();
            return "Message: " + customMessage + "\nPod Name: " + podName + "\n";
        } catch (UnknownHostException e) {
            return "Message: " + customMessage + "\nPod Name: Unknown\n";
        }
    }
}
