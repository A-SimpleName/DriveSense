// errorHandling/errorHandling.ts
// Einheitlicher Fehlertyp für das gesamte Projekt
export type AppError = {
    message: string;
    fieldErrors?: Record<string, string> | null;
    status?: number;
};
 
// Aus einem httpService-Fehler (err.message + err.errors) einen AppError machen
export function toAppError(err: any): AppError {
    return {
        message: err?.message || "Unbekannter Fehler",
        fieldErrors: err?.errors || null,
        status: err?.status,
    };
}
 
// Nur die Nachricht als String (für einfache Fehleranzeigen)
export function getErrorMessage(error: AppError | any): string {
    if (error?.fieldErrors) {
        return Object.values(error.fieldErrors).join(", ");
    }
    return error?.message || "Unbekannter Fehler";
}
 
// Feldfehler für Inline-Validierung in Forms
export function getFieldErrors(error: AppError | any): Record<string, string> | null {
    return error?.fieldErrors || null;
}