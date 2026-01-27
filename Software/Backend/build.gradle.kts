plugins {
    id("java")
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")

    implementation("org.xerial:sqlite-jdbc:3.45.1.0")
    implementation("com.mysql:mysql-connector-j:9.1.0")
}



tasks.test {
    useJUnitPlatform()
}