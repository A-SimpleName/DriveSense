# ER-Diagramm



## **Tabellen**



### USER



|ID|FNAME|LNAME|USERNAME|PWD|ACCOUNTTYPE|



### ACCOUNT



|ID|USER.ID|NAME|



### CAR



|ID|USER.ID|MODEL|CONSUMPTION|LICENSEPLATE|MILEAGE|



### TRACKING



|ID|USER.ID|CAR.ID|STARTTIME|ENDTIME|DISTANCE|WEATHER|TYPE|



### TRACKINGPOINT



|ID|USER.ID|CAR.ID|STARTTIME|ENDTIME|DISTANCE|WEATHER\_MAIN|WEATHER\_DESCRIPTION|TYPE|



### PROTOCOL



|ID|TRACKING.ID|ROAD\_SURFACE\_CONDITIONS|WEATHER\_RAW|



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





