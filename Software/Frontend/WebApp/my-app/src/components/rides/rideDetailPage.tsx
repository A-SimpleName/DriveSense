import { useParams } from "react-router-dom";

function RideDetailPage() {
    const { id } = useParams();
    return (  <h1>Ride Details</h1>);
}

export default RideDetailPage;