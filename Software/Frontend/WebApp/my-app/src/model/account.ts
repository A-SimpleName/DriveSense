export interface Account {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    pwd: string;
    created_at: Date;
}

export interface AccountResponse {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    birthdate: Date;
    created_at: Date;
}
