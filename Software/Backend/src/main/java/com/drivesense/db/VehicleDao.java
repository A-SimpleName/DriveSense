package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.exceptions.BadRequestException;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.Vehicle;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class VehicleDao {

    @Autowired
    private DbConnection dbConnection;

    // ── Lesen ───────────────────────────────────────────────────────────────

    /** Alle aktiven (nicht soft-gelöschten) Vehicles eines Accounts. */
    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        String sql = """
            SELECT v.id, v.model, v.licenseplate, v.mileage,
                   acc.fname AS owner_account_name,
                   p.name   AS owner_profile_name,
                   pv2.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv2      ON pv2.vehicle_id = v.id
            JOIN profile p2               ON p2.id = pv2.profile_id AND p2.account_id = ? AND p2.deleted_at IS NULL
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p                ON p.id = pv_owner.profile_id AND p.deleted_at IS NULL
            JOIN account acc              ON acc.id = p.account_id AND acc.deleted_at IS NULL
            WHERE v.deleted_at IS NULL
            """;
        return query(sql, ps -> ps.setInt(1, accountId));
    }

    /** Alle aktiven Vehicles eines Profils. */
    public List<VehicleDto> getAllVehiclesByProfile(int profileId) {
        String sql = """
            SELECT v.id, v.model, v.licenseplate, v.mileage,
                   acc.fname    AS owner_account_name,
                   p_owner.name AS owner_profile_name,
                   pv.role      AS my_role
            FROM profile_vehicle pv
            JOIN vehicle v                ON v.id = pv.vehicle_id AND v.deleted_at IS NULL
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p_owner          ON p_owner.id = pv_owner.profile_id AND p_owner.deleted_at IS NULL
            JOIN account acc              ON acc.id = p_owner.account_id AND acc.deleted_at IS NULL
            WHERE pv.profile_id = ?
            """;
        return query(sql, ps -> ps.setInt(1, profileId));
    }

    /**
     * Ein einzelnes aktives Vehicle mit Zugriffsprüfung per Account.
     * Wird auch für Trips verwendet, die auf ein soft-gelöschtes Fahrzeug verweisen –
     * dafür existiert {@link #getByIdForTrip(int)}.
     */
    public VehicleDto getById(int vehicleId, int accountId) {
        String sql = """
            SELECT v.id, v.model, v.licenseplate, v.mileage,
                   acc.fname    AS owner_account_name,
                   p.name       AS owner_profile_name,
                   pv_user.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv_user   ON pv_user.vehicle_id = v.id
            JOIN profile p_user            ON p_user.id = pv_user.profile_id AND p_user.account_id = ? AND p_user.deleted_at IS NULL
            JOIN profile_vehicle pv_owner  ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p                 ON p.id = pv_owner.profile_id AND p.deleted_at IS NULL
            JOIN account acc               ON acc.id = p.account_id AND acc.deleted_at IS NULL
            WHERE v.id = ? AND v.deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, vehicleId);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? mapDetail(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Vehicles", e);
        }
    }

    /**
     * Lädt ein Vehicle ohne Soft-Delete-Filter – für Trip-Historien-Abfragen,
     * bei denen das Fahrzeug inzwischen soft-gelöscht sein kann.
     */
    public Vehicle getByIdForTrip(int vehicleId) {
        String sql = "SELECT id, model, licenseplate, mileage, deleted_at FROM vehicle WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, vehicleId);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return null;
            Vehicle v = new Vehicle();
            v.setId(rs.getInt("id"));
            v.setModel(rs.getString("model"));
            v.setLicensePlate(rs.getString("licenseplate"));
            v.setMileage(rs.getInt("mileage"));
            Timestamp del = rs.getTimestamp("deleted_at");
            if (del != null) v.setDeletedAt(del.toLocalDateTime());
            return v;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Vehicles", e);
        }
    }

    /** Admin-Sicht: alle aktiven Vehicles. */
    public List<VehicleDto> getAllVehicles() {
        String sql = """
            SELECT v.id, v.model, v.licenseplate, v.mileage,
                   acc.fname    AS owner_account_name,
                   p.name       AS owner_profile_name,
                   pv_owner.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p               ON p.id = pv_owner.profile_id AND p.deleted_at IS NULL
            JOIN account acc             ON acc.id = p.account_id AND acc.deleted_at IS NULL
            WHERE v.deleted_at IS NULL
            """;
        return query(sql, ps -> {});
    }

    // ── Schreiben ───────────────────────────────────────────────────────────

    public Vehicle insert(Vehicle vehicle, int profileId) {
        String sqlVehicle = "INSERT INTO vehicle (model, licenseplate, mileage) VALUES (?,?,?)";
        String sqlLink    = "INSERT INTO profile_vehicle (profile_id, vehicle_id, role) VALUES (?,?,?)";

        try (Connection conn = dbConnection.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps1 = conn.prepareStatement(sqlVehicle, Statement.RETURN_GENERATED_KEYS)) {
                    ps1.setString(1, vehicle.getModel());
                    ps1.setString(2, vehicle.getLicensePlate());
                    ps1.setInt(3, vehicle.getMileage());
                    ps1.executeUpdate();
                    try (ResultSet rs = ps1.getGeneratedKeys()) {
                        if (!rs.next()) throw new SQLException("Keine generierte Fahrzeug-ID erhalten");
                        int vehicleId = rs.getInt(1);
                        vehicle.setId(vehicleId);
                        try (PreparedStatement ps2 = conn.prepareStatement(sqlLink)) {
                            ps2.setInt(1, profileId);
                            ps2.setInt(2, vehicleId);
                            ps2.setString(3, "OWNER");
                            ps2.executeUpdate();
                        }
                    }
                }
                conn.commit();
                return vehicle;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }
        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState()) && e.getMessage() != null
                    && e.getMessage().contains("uq_vehicle_licenseplate")) {
                throw new BadRequestException("Kennzeichen ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Speichern des Vehicles", e);
        }
    }

    /**
     * Aktualisiert model, licenseplate, mileage – nur wenn Account OWNER ist
     * und das Vehicle nicht soft-gelöscht ist.
     */
    public void update(Vehicle vehicle, int accountId) {
        String sql = """
            UPDATE vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id AND pv.role = 'OWNER'
            JOIN profile p          ON p.id = pv.profile_id AND p.account_id = ? AND p.deleted_at IS NULL
            SET v.model = ?, v.licenseplate = ?, v.mileage = ?
            WHERE v.id = ? AND v.deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setString(2, vehicle.getModel());
            ps.setString(3, vehicle.getLicensePlate());
            ps.setInt(4, vehicle.getMileage());
            ps.setInt(5, vehicle.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState()) && e.getMessage() != null
                    && e.getMessage().contains("uq_vehicle_licenseplate")) {
                throw new BadRequestException("Kennzeichen ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Aktualisieren des Vehicles", e);
        }
    }

    /**
     * Soft-Delete eines Vehicles.
     * Nur der OWNER (über seinen Account) darf das Fahrzeug löschen.
     * Historische Trips bleiben über die Snapshot-Felder erhalten.
     */
    public boolean softDelete(int vehicleId, int accountId) {
        String sql = """
            UPDATE vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id AND pv.role = 'OWNER'
            JOIN profile p          ON p.id = pv.profile_id AND p.account_id = ? AND p.deleted_at IS NULL
            SET v.deleted_at = NOW()
            WHERE v.id = ? AND v.deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, vehicleId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen des Vehicles", e);
        }
    }

    /**
     * Entfernt eine Profil-Fahrzeug-Verknüpfung (CO_OWNER / DRIVER verlässt das Fahrzeug).
     * Das Vehicle selbst wird NICHT gelöscht.
     */
    public boolean removeProfileAssociation(int vehicleId, int profileId, int accountId) {
        String sql = """
            DELETE pv FROM profile_vehicle pv
            JOIN profile p ON p.id = pv.profile_id AND p.account_id = ?
            WHERE pv.vehicle_id = ? AND pv.profile_id = ?
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, vehicleId);
            ps.setInt(3, profileId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Entfernen der Fahrzeug-Verknüpfung", e);
        }
    }

    /**
     * Fügt eine profile_vehicle Verknüpfung hinzu (nach Invitation-Annahme).
     */
    public void addProfileAssociation(int vehicleId, int profileId, String role) {
        String sql = "INSERT INTO profile_vehicle (profile_id, vehicle_id, role) VALUES (?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, profileId);
            ps.setInt(2, vehicleId);
            ps.setString(3, role);
            ps.executeUpdate();
        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState())) {
                throw new BadRequestException("Dieses Profil hat bereits Zugriff auf das Fahrzeug");
            }
            throw new DatabaseException("Fehler beim Hinzufügen der Fahrzeug-Verknüpfung", e);
        }
    }

    // ── Hilfsmethoden ───────────────────────────────────────────────────────

    @FunctionalInterface
    private interface PreparedStatementSetter {
        void set(PreparedStatement ps) throws SQLException;
    }

    private List<VehicleDto> query(String sql, PreparedStatementSetter setter) {
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            setter.set(ps);
            ResultSet rs = ps.executeQuery();
            List<VehicleDto> list = new ArrayList<>();
            while (rs.next()) list.add(mapDetail(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Vehicles", e);
        }
    }

    private VehicleDto mapDetail(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();
        dto.setId(rs.getInt("id"));
        dto.setModel(rs.getString("model"));
        dto.setLicensePlate(rs.getString("licenseplate"));
        dto.setMileage(rs.getInt("mileage"));
        dto.setOwnerAccountName(rs.getString("owner_account_name"));
        dto.setOwnerProfileName(rs.getString("owner_profile_name"));
        dto.setMyRole(rs.getString("my_role"));
        return dto;
    }
}
