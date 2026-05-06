package com.drivesense.exceptions;

public class PdfExportException extends RuntimeException {
    public PdfExportException(String message,Throwable cause) {
        super(message,cause);
    }
}
