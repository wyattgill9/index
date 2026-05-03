plugins {
    java
    id("com.gradleup.shadow") version "9.4.1"
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("net.minestom:minestom:2026.04.13-1.21.11")
    implementation("ch.qos.logback:logback-classic:1.5.32")
}

tasks.shadowJar {
    archiveClassifier.set("")
    manifest {
        attributes["Main-Class"] = "dev.ix.minestom.Main"
    }
}
