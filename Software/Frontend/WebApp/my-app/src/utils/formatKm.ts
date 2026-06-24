const kmFormatter = new Intl.NumberFormat("de-AT", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
});

export function formatKm(value: number) {
    const rounded = Math.round((value + Number.EPSILON) * 100) / 100;
    return kmFormatter.format(rounded);
}
