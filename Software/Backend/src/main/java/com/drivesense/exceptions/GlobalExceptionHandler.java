package com.drivesense.exceptions;

import jakarta.validation.ConstraintViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // Validation Fehler (@Valid) → 400
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> handleValidationErrors(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(error -> errors.put(error.getField(), error.getDefaultMessage()));
        return ResponseEntity.status(400).body(errors);
    }

    // Nicht gefunden → 404
    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(NotFoundException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        return ResponseEntity.status(404).body(error);
    }

    // Keine Berechtigung → 403
    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<Map<String, String>> handleUnauthorized(UnauthorizedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        return ResponseEntity.status(403).body(error);
    }

    // Falsche Eingabe → 400
    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(BadRequestException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        return ResponseEntity.status(400).body(error);
    }

    // Datenbankfehler → 500
    @ExceptionHandler(DatabaseException.class)
    public ResponseEntity<Map<String, String>> handleDatabaseException(DatabaseException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "Datenbankfehler – bitte später erneut versuchen");
        return ResponseEntity.status(500).body(error);
    }

    @ExceptionHandler(ExternalApiException.class)
    public ResponseEntity<Map<String, String>> handleExternalApi(ExternalApiException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "Externer Dienst nicht verfügbar – bitte später erneut versuchen");
        return ResponseEntity.status(503).body(error); // 503 = Service Unavailable
    }

    // Alles andere → 500
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "Interner Serverfehler");
        return ResponseEntity.status(500).body(error);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, String>> handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getConstraintViolations()
                .forEach(v -> errors.put(
                        v.getPropertyPath().toString(),
                        v.getMessage()
                ));
        return ResponseEntity.status(400).body(errors);
    }
}
