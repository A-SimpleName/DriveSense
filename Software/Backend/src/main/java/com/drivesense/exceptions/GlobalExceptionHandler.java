package com.drivesense.exceptions;

import jakarta.validation.ConstraintViolationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.HashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // @Valid Fehler → fieldErrors
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(error -> fieldErrors.put(error.getField(), error.getDefaultMessage()));
        return fieldErrorResponse("Validierungsfehler", fieldErrors);
    }

    // @Validated auf Service-Ebene
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraintViolation(ConstraintViolationException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getConstraintViolations()
                .forEach(v -> fieldErrors.put(
                        v.getPropertyPath().toString(),
                        v.getMessage()
                ));
        return fieldErrorResponse("Validierungsfehler", fieldErrors);
    }

    // Manuelle Feldfehler aus Service (z.B. "email bereits vergeben" → erscheint inline beim Feld)
    @ExceptionHandler(FieldValidationException.class)
    public ResponseEntity<Map<String, Object>> handleFieldValidation(FieldValidationException ex) {
        return fieldErrorResponse("Validierungsfehler", ex.getFieldErrors());
    }

    @ExceptionHandler(PdfExportException.class)
    public ResponseEntity<Map<String, String>> handlePdfExport(PdfExportException ex) {
        log.error("PDF Export Fehler", ex);
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        if (ex.getCause() != null && ex.getCause().getMessage() != null) {
            error.put("detail", ex.getCause().getMessage());
        }
        return ResponseEntity.status(500).body(error);
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

    @ExceptionHandler(NotVerifiedException.class)
    public ResponseEntity<Map<String, String>> handleNotVerified(NotVerifiedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        return ResponseEntity.status(406).body(error);
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
        if (ex.getCause() != null && ex.getCause().getMessage() != null) {
            error.put("detail", ex.getCause().getMessage());
        }
        return ResponseEntity.status(500).body(error);
    }

    @ExceptionHandler(ExternalApiException.class)
    public ResponseEntity<Map<String, String>> handleExternalApi(ExternalApiException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "Externer Dienst nicht verfügbar – bitte später erneut versuchen");
        return ResponseEntity.status(503).body(error);
    }

    // Falsche HTTP-Methode → 405
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<Map<String, String>> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "HTTP-Methode nicht erlaubt: " + ex.getMethod());
        return ResponseEntity.status(405).body(error);
    }

    // Alles andere → 500
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneral(Exception ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", "Interner Serverfehler");
        return ResponseEntity.status(500).body(error);
    }

    // ── Hilfsmethoden ────────────────────────────────────────────────────────

    private ResponseEntity<Map<String, Object>> fieldErrorResponse(String message, Map<String, String> fieldErrors) {
        Map<String, Object> body = new HashMap<>();
        body.put("message", message);
        body.put("errors", fieldErrors);
        return ResponseEntity.badRequest().body(body);
    }
}
