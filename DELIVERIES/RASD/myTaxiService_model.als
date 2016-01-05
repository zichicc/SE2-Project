module mytaxiservice
open util/boolean
sig string{}
sig float{}
sig TaxiDriver{
	username : one string,
	password : one string,
	taxicode : one string,
	licence : one string,
	timestamp: lone Int,
	rideResponse: one Bool
}
sig Passenger{
	username : one string,
	password : one string
}
abstract  sig Ride{
	idRide:one Int,
	origin : one Location,
	has : one Passenger,
	assigned_to : lone TaxiDriver,
	taxiResponse: lone Bool,
	endRide: one Bool
}
sig Request extends Ride{}
sig Reservation extends Ride{
	date : one Int,
	destination : one Location
}
sig Location
{	
	latitude : one float,
	longitude : one float
}
sig Zone{
	idzone : one Int,
	queue : one Queue,
	vertex: some Location
}{ #vertex=4
}
sig Queue{
	idqueue : one Int,
	available_drivers : set TaxiDriver,
 }

fact Location{
//	Two locations cannot have the same latitude and longitude
	no disj l1,l2:Location | l1.latitude=l2.latitude and l1.longitude=l2.longitude
}
fact Zone{
 //Two or more zones cannot have the same idzone
	no disj z1,z2:Zone | z1.idzone=z2.idzone
//	Two or more zones cannot be associated to the same queue 
	no disj z1,z2:Zone | z1.queue = z2.queue
//	Two or more zones cannot have the same vertex
	all disj z1,z2:Zone | z1.vertex!=z2.vertex
}
fact Queue{
 //Two or more queues cannot have the same idzone
	no disj q1,q2:Queue | q1.idqueue=q2.idqueue
//	One queue is associated to one zone
 	all q:Queue |  one z:Zone | q in z.queue
}
fact TaxiDriver{
//	Two or more taxi drivers cannot have the same username
	no disj t1,t2:TaxiDriver | t1.username=t2.username
//	Two or more taxi drivers  cannot have the same licence
	no disj t1,t2:TaxiDriver | t1.licence=t2.licence
//	Two or more taxi drivers cannot have the same taxicode
	all disj t1,t2:TaxiDriver | t1.taxicode!=t2.taxicode
// One taxi driver can be at most in one queue at the same time
	no t:TaxiDriver | some disj q1,q2: Queue | t in q1.available_drivers and t in q2.available_drivers
// If a taxi driver is assigned to a ride, he must not belong to any queue 
	all t:TaxiDriver,r:Ride,q:Queue | r.assigned_to=t implies t not in q.available_drivers
// A taxi driver can serve at most one ride at the same time 
	no disj r1,r2:Ride | r1.assigned_to=r2.assigned_to and r1.assigned_to!=none
//	If a taxi driver is in a queue, the timestamp is not null
	all t:TaxiDriver,q:Queue | t  in q.available_drivers  implies t.timestamp!=none
//If a taxi driver have a ride assigned the timestamp is null
	all t:TaxiDriver,r:Ride | t= r.assigned_to implies t.timestamp=none
// the taxiResponse is possible true if the taxi is in the queue
	no t:TaxiDriver,q:Queue |  t.rideResponse=True and t not in q.available_drivers
} 

fact Passenger{
// Two or more Passengers cannot have the same username
	no disj p1,p2:Passenger | p1.username=p2.username
// A Passenger cannot have two rides with the same date
	all disj r1,r2:Ride | r1.has=r2.has implies r1.date!=r2.date
// A Passenger can do one request at once
	no disj r1,r2:Request | r1.has = r2.has
}

fact Ride{
//	Two or more rides cannot have the same idRide
	all disj r1,r2:Ride | r1.idRide!=r2.idRide
// Ride that has an origin different from destination
	all disj r1,r2:Ride | r1=r2 implies r1.origin!=r2.destination
// A Passenger can have only one ride assigned at once 
	all disj r1,r2:Ride | (r1.has=r2.has and r1.assigned_to!=none) implies r2.assigned_to=none
//	If a Passenger has one request they cannot have a  reservation already assigned to a taxi
	all  r1:Request,r2:Reservation | r1.has=r2.has implies r2.assigned_to=none
// A taxiResponse is not null if and only if the ride have a taxi assigned
	no r:Ride | r.taxiResponse!=none and r.assigned_to=none
// A endRide is not null if and only if the taxiResponse is true
	all r:Ride | r.endRide!=none implies r.taxiResponse=True 
}

assert TaxiAssignedToTwoOrMoreQueue{
	no t:TaxiDriver | some  disj q1,q2: Queue | t in q1.available_drivers and t in  q2.available_drivers
}

check TaxiAssignedToTwoOrMoreQueue

assert PassengerWithTwoRideAssigned{
	no disj r1,r2:Ride | r1.has=r2.has and r1.assigned_to!=none and r2.assigned_to!=none
}

check PassengerWithTwoRideAssigned

pred MoreRide{
	#Ride>5
	#Passenger=3
	some disj r,r1:Ride | r.assigned_to!=none and r1.assigned_to!=none
}

run MoreRide for 6 but 8 Ride

pred GenericWorld {
	#Queue>2
	#Ride>2
	#Passenger>2
	some q:Queue | q.available_drivers!=none
	some disj r,r1:Ride | r.assigned_to!=none and r1.assigned_to!=none
}

run GenericWorld for 10 
