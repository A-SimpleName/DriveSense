package com.drivesense.exceptions;

import java.util.Map;

/**
 * Für manuelle Feldfehler die als inline-Fehler im Frontend angezeigt werden sollen.
 * Beispiel: "email bereits vergeben" → erscheint direkt beim Email-Feld, nicht als Banner.
 */
public class FieldValidationException extends RuntimeException {

    private final Map<String, String> fieldErrors;

    // Einzelnes Feld
    public FieldValidationException(String field, String message) {
        super(message);
        this.fieldErrors = Map.of(field, message);
    }

    // Mehrere Felder gleichzeitig
    public FieldValidationException(Map<String, String> fieldErrors) {
        super("Validierungsfehler");
        this.fieldErrors = fieldErrors;
    }

    public Map<String, String> getFieldErrors() {
        return fieldErrors;
    }
}
