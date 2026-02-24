export function logout() {
     localStorage.removeItem("token");
}

export function login(email: string, password: string) {
    console.log(email, password);
    // Backend authentication logic would go here
    localStorage.setItem("token","prototype")
}

export function isAuthenticated(): boolean {
    return !!localStorage.getItem("token");
}

export function SignUp(email: string, password: string) {
    console.log(email, password);
    // Backend sign-up logic would go here
}