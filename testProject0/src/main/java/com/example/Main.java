package com.example;

public class Main {
    public static void main(String[] args) {
        System.out.println("Hello world!");

        int x = 10;
        if (x == 10){
            System.out.println("DP 1");
        } else if (x < 0){
            System.out.println("DP 2");
        } else {
            System.out.println("Still DP 1");
        } 

        int count = 0;
        while (count < x) {
            count += 1;
        }

        if (x == 10){
            System.out.println("DP 1");
        } else if (x < 0){
            System.out.println("DP 2");
        } else {
            System.out.println("Still DP 1");
        } 

        while (count < x) {
            count += 1;
        }

        if (x == 10){
            System.out.println("DP 1");
        } else if (x < 0){
            System.out.println("DP 2");
        } else {
            System.out.println("Still DP 1");
        } 

        while (count < x) {
            count += 1;
        }
    }
}