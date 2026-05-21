export interface Account {
    id: number;
    fName: string;
    lName: string;
    email: string;
    pwd: string;
    created_at: Date;
}

export interface AccountResponse {
    id: number;
    fName: string;
    lName: string;
    email: string;
    birthdate: Date;
    created_at: Date;
}