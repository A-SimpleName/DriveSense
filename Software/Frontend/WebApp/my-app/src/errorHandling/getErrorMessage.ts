export function getErrorMessage(error: any): string {

    // Validation Errors (vom httpService als err.errors gesetzt)
    if (error?.fieldErrors) {
        return Object.values(error.fieldErrors).join(", ");
    }

    // Normale Message (z.B. new Error("Fahrzeug nicht gefunden"))
    if (error?.message) {
        return error.message;
    }

    return "Unbekannter Fehler";
}

export function getFieldErrors(error: any): Record<string, string> | null {
    if (error?.fieldErrors) {
        return error.fieldErrors;
    }
    return null;
}