export function getErrorMessage(error: any): string {

    // Kein Server erreichbar
    if (!error?.response) {
        return "Server nicht erreichbar"
    }

    const data = error.response.data

    // Validation Errors (Backend: { message, errors })
    if (data?.errors) {
        return Object.values(data.errors).join(", ")
    }

    // Normale Message
    if (data?.message) {
        return data.message
    }

    return "Unbekannter Fehler"
}