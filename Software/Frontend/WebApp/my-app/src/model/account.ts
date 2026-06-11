export interface Account {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    pendingEmail?: string | null;
    birthdate?: string | null;
    created_at?: string;
}

export interface AccountResponse {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    pendingEmail?: string | null;
    birthdate?: string | null;
    created_at?: string;
}
