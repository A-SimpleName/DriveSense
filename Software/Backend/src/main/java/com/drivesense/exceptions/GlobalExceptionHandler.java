package com.drivesense.exceptions;

import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.http.converter.HttpMessageNotReadableException;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // Spring @Valid Fehler → fieldErrors
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(e -> fieldErrors.put(e.getField(), e.getDefaultMessage()));
        return fieldErrorResponse("Validierungsfehler", fieldErrors);
    }

    // @Validated auf Service-Ebene
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getConstraintViolations()
                .forEach(v -> fieldErrors.put(v.getPropertyPath().toString(), v.getMessage()));
        return fieldErrorResponse("Validierungsfehler", fieldErrors);
    }

    // NEU: manuelle Feldfehler aus Service (z.B. "email bereits vergeben")
    @ExceptionHandler(FieldValidationException.class)
    public ResponseEntity<Map<String, Object>> handleFieldValidation(FieldValidationException ex) {
        return fieldErrorResponse("Validierungsfehler", ex.getFieldErrors());
    }

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(NotFoundException ex) {
        return error(404, ex.getMessage());
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorized(UnauthorizedException ex) {
        return error(403, ex.getMessage());
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(BadRequestException ex) {
        return error(400, ex.getMessage());
    }

    @ExceptionHandler(PdfExportException.class)
    public ResponseEntity<Map<String, String>> handlePdfExport(PdfExportException ex) {
        log.error("PDF Export Fehler", ex);
        return error(500, ex.getMessage());
    }

    @ExceptionHandler(DatabaseException.class)
    public ResponseEntity<Map<String, String>> handleDatabase(DatabaseException ex) {
        log.error("Datenbankfehler: {}", ex.getMessage(), ex);
        return error(500, "Datenbankfehler – bitte später erneut versuchen");
    }

    @ExceptionHandler(ExternalApiException.class)
    public ResponseEntity<Map<String, String>> handleExternalApi(ExternalApiException ex) {
        log.warn("Externer API-Fehler: {}", ex.getMessage(), ex);
        return error(503, "Externer Dienst nicht verfügbar – bitte später erneut versuchen");
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, String>> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
        return error(405, "HTTP-Methode nicht erlaubt: " + ex.getMethod());
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, String>> handleUnreadable(HttpMessageNotReadableException ex) {
        return error(400, "Ungültiges Request-Format");
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<Map<String, String>> handleMissingParam(MissingServletRequestParameterException ex) {
        return error(400, "Pflichtparameter fehlt: " + ex.getParameterName());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        log.error("Unbehandelter Fehler", ex);
        return error(500, "Interner Serverfehler");
    }

    // Hilfsmethoden
    private ResponseEntity<Map<String, String>> error(int status, String message) {
        return ResponseEntity.status(status).body(Map.of("message", message));
    }

    private ResponseEntity<Map<String, Object>> fieldErrorResponse(String message, Map<String, String> fieldErrors) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", message);
        body.put("errors", fieldErrors);
        return ResponseEntity.badRequest().body(body);
    }
}