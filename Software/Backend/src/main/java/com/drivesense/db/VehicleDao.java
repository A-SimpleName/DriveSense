package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.dto.response.VehicleDto;
import com.drivesense.dto.response.VehicleMemberResponse;
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

    // ─────────────────────────────────────────────
    // READ
    // ─────────────────────────────────────────────

    public List<VehicleDto> getAllVehiclesByAccount(int accountId) {
        String sql = """
            SELECT v.id, v.model, v.license_plate, v.mileage,
                   acc.first_name AS owner_account_name,
                   p.name AS owner_profile_name,
                   pv.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id
            JOIN profile p ON p.id = pv.profile_id AND p.account_id = ? AND p.deleted_at IS NULL
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p_owner ON p_owner.id = pv_owner.profile_id AND p_owner.deleted_at IS NULL
            JOIN account acc ON acc.id = p_owner.account_id AND acc.deleted_at IS NULL
            WHERE v.deleted_at IS NULL
        """;

        return query(sql, ps -> ps.setInt(1, accountId));
    }

    public List<VehicleDto> getAllVehiclesByProfile(int profileId) {
        String sql = """
            SELECT v.id, v.model, v.license_plate, v.mileage,
                   acc.first_name AS owner_account_name,
                   p_owner.name AS owner_profile_name,
                   pv.role AS my_role
            FROM profile_vehicle pv
            JOIN vehicle v ON v.id = pv.vehicle_id AND v.deleted_at IS NULL
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p_owner ON p_owner.id = pv_owner.profile_id AND p_owner.deleted_at IS NULL
            JOIN account acc ON acc.id = p_owner.account_id AND acc.deleted_at IS NULL
            WHERE pv.profile_id = ?
        """;

        return query(sql, ps -> ps.setInt(1, profileId));
    }

    public VehicleDto getById(int vehicleId, int accountId) {
        String sql = """
            SELECT v.id, v.model, v.license_plate, v.mileage,
                   acc.first_name AS owner_account_name,
                   p_owner.name AS owner_profile_name,
                   pv.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv_user ON pv_user.vehicle_id = v.id
            JOIN profile p_user ON p_user.id = pv_user.profile_id AND p_user.account_id = ? AND p_user.deleted_at IS NULL
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p_owner ON p_owner.id = pv_owner.profile_id AND p_owner.deleted_at IS NULL
            JOIN account acc ON acc.id = p_owner.account_id AND acc.deleted_at IS NULL
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

    public List<VehicleDto> getAllVehicles() {
        String sql = """
            SELECT v.id, v.model, v.license_plate, v.mileage,
                   acc.first_name AS owner_account_name,
                   p.name AS owner_profile_name,
                   pv_owner.role AS my_role
            FROM vehicle v
            JOIN profile_vehicle pv_owner ON pv_owner.vehicle_id = v.id AND pv_owner.role = 'OWNER'
            JOIN profile p ON p.id = pv_owner.profile_id AND p.deleted_at IS NULL
            JOIN account acc ON acc.id = p.account_id AND acc.deleted_at IS NULL
            WHERE v.deleted_at IS NULL
        """;

        return query(sql, ps -> {});
    }

    public List<VehicleMemberResponse> getMembersByVehicleId(int vehicleId) {
        String sql = """
            SELECT p.id AS profile_id,
                   p.name AS profile_name,
                   p.role AS profile_role,
                   TRIM(CONCAT(COALESCE(acc.first_name, ''), ' ', COALESCE(acc.last_name, ''))) AS account_name,
                   acc.email AS account_email,
                   pv.role AS vehicle_role
            FROM profile_vehicle pv
            JOIN vehicle v ON v.id = pv.vehicle_id AND v.deleted_at IS NULL
            JOIN profile p ON p.id = pv.profile_id AND p.deleted_at IS NULL
            JOIN account acc ON acc.id = p.account_id AND acc.deleted_at IS NULL
            WHERE pv.vehicle_id = ?
            ORDER BY
                CASE pv.role
                    WHEN 'OWNER' THEN 0
                    WHEN 'CO_OWNER' THEN 1
                    ELSE 2
                END,
                p.name
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, vehicleId);

            ResultSet rs = ps.executeQuery();
            List<VehicleMemberResponse> list = new ArrayList<>();

            while (rs.next()) {
                list.add(mapMember(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Fahrzeug-Freigaben", e);
        }
    }

    // ─────────────────────────────────────────────
    // TRIP SUPPORT (soft delete safe)
    // ─────────────────────────────────────────────

    public Vehicle getByIdForTrip(int vehicleId) {
        String sql = """
            SELECT id, model, license_plate, mileage, deleted_at
            FROM vehicle
            WHERE id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, vehicleId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                Vehicle v = new Vehicle();
                v.setId(rs.getInt("id"));
                v.setModel(rs.getString("model"));
                v.setLicensePlate(rs.getString("license_plate"));
                v.setMileage(rs.getInt("mileage"));
                return v;
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Vehicles", e);
        }
    }

    // ─────────────────────────────────────────────
    // WRITE
    // ─────────────────────────────────────────────

    public Vehicle insert(Vehicle vehicle, int profileId) {
        String sqlVehicle = """
            INSERT INTO vehicle (model, license_plate, mileage)
            VALUES (?,?,?)
        """;

        String sqlLink = """
            INSERT INTO profile_vehicle (profile_id, vehicle_id, role)
            VALUES (?,?,?)
        """;

        try (Connection conn = dbConnection.getConnection()) {
            conn.setAutoCommit(false);

            try {
                int vehicleId;

                try (PreparedStatement ps = conn.prepareStatement(sqlVehicle, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, vehicle.getModel());
                    ps.setString(2, vehicle.getLicensePlate());
                    ps.setInt(3, vehicle.getMileage());
                    ps.executeUpdate();

                    ResultSet rs = ps.getGeneratedKeys();
                    if (!rs.next()) throw new SQLException("Keine Vehicle-ID erhalten");

                    vehicleId = rs.getInt(1);
                    vehicle.setId(vehicleId);
                }

                try (PreparedStatement ps = conn.prepareStatement(sqlLink)) {
                    ps.setInt(1, profileId);
                    ps.setInt(2, vehicleId);
                    ps.setString(3, "OWNER");
                    ps.executeUpdate();
                }

                conn.commit();
                return vehicle;

            } catch (SQLException e) {
                conn.rollback();
                throw e;
            }

        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState())) {
                throw new BadRequestException("Kennzeichen ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Speichern des Vehicles", e);
        }
    }

    public void update(Vehicle vehicle, int accountId) {
        String sql = """
            UPDATE vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id AND pv.role = 'OWNER'
            JOIN profile p ON p.id = pv.profile_id AND p.account_id = ? AND p.deleted_at IS NULL
            SET v.model = ?, v.license_plate = ?, v.mileage = ?
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
            if ("23000".equals(e.getSQLState())) {
                throw new BadRequestException("Kennzeichen ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Aktualisieren des Vehicles", e);
        }
    }

    public boolean softDelete(int vehicleId, int accountId) {
        String sql = """
            UPDATE vehicle v
            JOIN profile_vehicle pv ON pv.vehicle_id = v.id AND pv.role = 'OWNER'
            JOIN profile p ON p.id = pv.profile_id AND p.account_id = ? AND p.deleted_at IS NULL
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
     * Entfernt die eigene Profilverknüpfung (CO_OWNER / DRIVER verlässt das Fahrzeug).
     * Prüft via JOIN dass das Profil wirklich zum angegebenen Account gehört.
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
     * OWNER entfernt ein beliebiges Mitglied (außer OWNER selbst – verhindert durch Service).
     * CO_OWNER entfernt nur DRIVER – wird durch Service sichergestellt, hier kein Extra-Check nötig.
     */
    public boolean removeMemberAssociation(int vehicleId, int targetProfileId) {
        String sql = """
            DELETE FROM profile_vehicle
            WHERE vehicle_id = ? AND profile_id = ?
        """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, vehicleId);
            ps.setInt(2, targetProfileId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Entfernen des Mitglieds", e);
        }
    }

    /**
     * Ändert die Rolle eines bestehenden Mitglieds (z.B. DRIVER -> CO_OWNER).
     * Berechtigung wird im Service geprüft, hier kein Extra-Check nötig.
     */
    public boolean updateMemberRole(int vehicleId, int targetProfileId, String newRole) {
        String sql = """
        UPDATE profile_vehicle
        SET role = ?
        WHERE vehicle_id = ? AND profile_id = ?
    """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, newRole);
            ps.setInt(2, vehicleId);
            ps.setInt(3, targetProfileId);

            return ps.executeUpdate() > 0;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren der Mitgliedsrolle", e);
        }
    }

    public void addProfileAssociation(int vehicleId, int profileId, String role) {
        String sql = """
            INSERT INTO profile_vehicle (profile_id, vehicle_id, role)
            VALUES (?,?,?)
        """;

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

    // ─────────────────────────────────────────────
    // INTERNAL
    // ─────────────────────────────────────────────

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

            while (rs.next()) {
                list.add(mapDetail(rs));
            }

            return list;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Vehicles", e);
        }
    }

    private VehicleDto mapDetail(ResultSet rs) throws SQLException {
        VehicleDto dto = new VehicleDto();
        dto.setId(rs.getInt("id"));
        dto.setModel(rs.getString("model"));
        dto.setLicensePlate(rs.getString("license_plate"));
        dto.setMileage(rs.getInt("mileage"));
        dto.setOwnerAccountName(rs.getString("owner_account_name"));
        dto.setOwnerProfileName(rs.getString("owner_profile_name"));
        dto.setMyRole(rs.getString("my_role"));
        return dto;
    }

    private VehicleMemberResponse mapMember(ResultSet rs) throws SQLException {
        VehicleMemberResponse member = new VehicleMemberResponse();
        member.setProfileId(rs.getInt("profile_id"));
        member.setProfileName(rs.getString("profile_name"));
        member.setProfileRole(rs.getString("profile_role"));
        member.setAccountName(rs.getString("account_name"));
        member.setAccountEmail(rs.getString("account_email"));
        member.setVehicleRole(rs.getString("vehicle_role"));
        return member;
    }
}