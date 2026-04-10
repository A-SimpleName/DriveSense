export function getFieldErrors(error: any): Record<string, string> | null {

    const data = error?.response?.data

    if (data?.errors) {
        return data.errors
    }

    return null
}