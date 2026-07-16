allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            // sdkdemo/android -> ../../plugins/blesdk/android/localRepo
            url = uri("${rootDir}/../../plugins/blesdk/android/localRepo")
        }
        maven {
            url = uri("https://nexus.huawo-wear.com/repository/maven-releases/")
            credentials {
                username = "huaworead"
                password = "huawo202301"
            }
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/public")
        }
        maven {
            url = uri("https://maven.aliyun.com/repository/google")
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
