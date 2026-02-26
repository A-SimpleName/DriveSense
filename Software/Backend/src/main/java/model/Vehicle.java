package model;

public class Vehicle {
    private int id;
    private int userId;
    private String model;
    private String licenseplate;
    private int mileage;

    public Vehicle() {}

    public Vehicle(int userId, String model, String licenseplate, int mileage) {
        this.userId = userId;
        this.model = model;
        this.licenseplate = licenseplate;
        this.mileage = mileage;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public String getLicenseplate() {
        return licenseplate;
    }

    public void setLicenseplate(String licenseplate) {
        this.licenseplate = licenseplate;
    }

    public int getMileage() {
        return mileage;
    }

    public void setMileage(int mileage) {
        this.mileage = mileage;
    }

    @Override
    public String toString() {
        return "Vehicle: " +
                "id: " + id +
                ", userId: " + userId +
                ", model: '" + model + '\'' +
                ", licenseplate: '" + licenseplate + '\'' +
                ", mileage: " + mileage;
    }
}
