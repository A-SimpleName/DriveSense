# ER-Diagramm



## **Tabellen**



### USER



|ID|FNAME|LNAME|USERNAME|PWD|ACCOUNT_ID|GROUP_ID|



### ACCOUNT



|ID|NAME|



### CAR



|ID|USER_ID|MODEL|CONSUMPTION|LICENSEPLATE|MILEAGE|



### TRACKING



|ID|USER_ID|CAR_ID|STARTTIME|ENDTIME|DISTANCE|WEATHER_MAIN|WEATHER_DESCRIPTION|TYPE|



### TRACKINGPOINT



|ID|TRACKING_ID|LAT|LNG|ACCURACY|SPEED|BEARING|TIMESTAMP|



### PROTOCOL



|ID|TRACKING_ID|ROAD_SURFACE_CONDITIONS|WEATHER_RAW|SIGN_DRIVER|SIGN_ATTENDANT|


### GRUOP


|ID|NAME|


### PROTOCOL_USER

|PROTOCOL_ID|USER_ID|


## **Beziehungen**



### USER – ACCOUNT:



1:1

*(jeder User hat genau einen Accounttyp)*



### USER – CAR:



1:N

*(ein User kann mehrere Autos besitzen)*



### USER – TRACKING:



1:N

*(ein User kann viele Fahrten haben)*



### TRACKING – TRACKINGPOINT:



1:N

*(eine Fahrt besteht aus vielen GPS-Punkten)*



### TRACKING – PROTOCOL:



1:1

*(jede Fahrt hat genau ein Protokoll)*





