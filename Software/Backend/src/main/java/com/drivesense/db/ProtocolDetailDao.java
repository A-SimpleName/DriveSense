package com.drivesense.db;

import com.drivesense.App;
import com.drivesense.DbConnection;
import com.drivesense.dto.ProtocolDto;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProtocolDetailDao {

    @Autowired
    private DbConnection dbConnection;

    public List<ProtocolDto> getAllWithDetailsbyUserId(int userId) {
        String sql = """
                    SELECT 
                        p.id AS protocol_id,
                        t.id AS trip_id
                        p.road_surface_conditions,
                        t.starttime,
                        t.endtime,
                        t.distance,
                        t.weather_main,
                        t.type,
                        v.licenseplate,
                        a.fname,
                        a.lname,
                        pu.user_role
                    FROM protocol p
                    JOIN trip t ON t.id = p.trip_id
                    JOIN vehicle v ON v.id = t.car_id
                    JOIN user u ON u.id = t.user_id
                    JOIN account a ON a.id = u.account_id
                    LEFT JOIN protocol_user pu ON pu.protocol_id = p.id
                    WHERE t.user_id = ?
                """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);

            ResultSet rs = ps.executeQuery();
            List<ProtocolDto> list = new ArrayList<>();
            while (rs.next()) {
                list.add(map(rs)); // direkt ins DTO mappen
            }
            return list;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    public ProtocolDto getByIdAndUserId(int id, int userId) {
        String sql = """
                    SELECT 
                        p.id AS protocol_id,
                        t.id AS trip_id
                        p.road_surface_conditions,
                        t.starttime, t.endtime, t.distance,
                        t.weather_main, t.type,
                        v.licenseplate,
                        a.fname, a.lname,
                        pu.user_role
                    FROM protocol p
                    JOIN trip t ON t.id = p.trip_id
                    JOIN vehicle v ON v.id = t.car_id
                    JOIN user u ON u.id = t.user_id
                    JOIN account a ON a.id = u.account_id
                    LEFT JOIN protocol_user pu ON pu.protocol_id = p.id
                    WHERE p.id = ? AND t.user_id = ?
                """;

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ps.setInt(2, userId);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }
            return null;

        } catch (SQLException e) {
            System.err.println(e.getMessage());
            return null;
        }
    }

    private ProtocolDto map(ResultSet rs) throws SQLException {
        ProtocolDto dto = new ProtocolDto();
        dto.setProtocolId(rs.getInt("protocol_id"));
        dto.setTripId(rs.getInt("trip_id"));
        dto.setRoadSurfaceConditions(rs.getString("road_surface_conditions"));
        dto.setStarttime(rs.getTimestamp("starttime").toLocalDateTime());
        dto.setEndtime(rs.getTimestamp("endtime").toLocalDateTime());
        dto.setDistance(rs.getInt("distance"));
        dto.setWeatherMain(rs.getString("weather_main"));
        dto.setType(rs.getString("type"));
        dto.setLicenseplate(rs.getString("licenseplate"));
        dto.setFname(rs.getString("fname"));
        dto.setLname(rs.getString("lname"));
        dto.setUserRole(rs.getString("user_role"));
        return dto;
    }
}