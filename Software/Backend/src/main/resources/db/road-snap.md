# Road Snap Persistence

Road snapping is handled by the backend after trip trackingpoints are received.
Clients must not call the Google Roads API.

## Schema

The migration `migration/2026-06-25-road-snap-status.sql` adds trip-level snap metadata:

- `road_snap_status`: `PENDING`, `SNAPPED`, or `FAILED`
- `road_snap_attempts`: number of failed snap attempts recorded for the trip
- `road_snap_last_error`: latest failure message, truncated by the DAO
- `road_snap_next_retry_at`: next scheduled retry time for `PENDING` trips
- `road_snap_updated_at`: last snap status update

It also adds `trackingpoint.point_source`:

- `RAW`: original client-provided GPS points
- `SNAPPED`: backend-generated Google Roads points

Fresh database installs must keep `init/DS_Create_Statements_3.7.sql` aligned with this migration.

## Runtime Flow

1. The client posts a trip with raw trackingpoints to the backend.
2. The backend stores the raw points as `point_source = 'RAW'`.
3. The backend immediately tries to snap the raw points through Google Roads.
4. On success, existing `SNAPPED` points are replaced, new snapped points are stored, and the trip is marked `SNAPPED`.
5. On failure, raw points remain available, the trip stays `PENDING`, and `road_snap_next_retry_at` is set with backoff.
6. A scheduled retry job processes due `PENDING` trips.

Reads from `TrackingpointDao.getByTripId` prefer `SNAPPED` points when present and fall back to `RAW` points otherwise.
This means clients can render the returned route directly without knowing whether the trip has already been snapped.

## Failure Handling

Road snapping is intentionally non-blocking. Trip creation must succeed even when Google Roads is unreachable, rate-limited, misconfigured, or returns malformed data.

After repeated failures, the trip is marked `FAILED`. The raw points are still retained, so an admin/manual retry flow can be added later without asking the user to re-upload the trip.
