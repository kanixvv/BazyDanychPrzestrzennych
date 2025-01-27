$timestamp = (Get-Date -Format "yyyyMMddHHmmss")
$path = "C:\Users\wika1\Desktop\Bazki\cw10\PROCESSED"

# Tworzenie katalogu PROCESSED, jeśli nie istnieje
if (-not (Test-Path -Path $path)) {
    New-Item -ItemType Directory -Path $path
}

# Funkcja do logowania zdarzeń
function log {
    param ($message)
    $log = "$(Get-Date -Format 'yyyyMMddHHmmss') $message"
    Write-Host $log
    Add-Content -Path "$path\script_${timestamp}.log" -Value $log
}

# Funkcja do logowania błędów
function error {
    param ($message)
    Log "Error: $message"
    Exit 1
}

# Zadanie 1a: Pobieranie pliku z internetu
try {
    log "Pobieranie plików"
    Invoke-WebRequest -Uri "https://home.agh.edu.pl/~wsarlej/Customers_Nov2024.zip" -OutFile "$path\Customers_Nov2024.zip"
    Invoke-WebRequest -Uri "https://home.agh.edu.pl/~wsarlej/Customers_old.csv" -OutFile "$path\Customers_old.csv"
} catch {
    error "Błąd podczas pobierania plików"
}

# Zadanie 1b: Rozpakowywanie pliku
try {
    log "Rozpakowywanie archiwum"
    Expand-Archive -Path "$path\Customers_Nov2024.zip" -DestinationPath "$path" -Force
} catch {
    error "Błąd podczas rozpakowywania"
}

# Zadanie 1c: Walidacja i czyszczenie danych
try {
    log "Walidacja danych"
    $file = Import-Csv -Path "$path\Customers_Nov2024.csv" -Delimiter ","
    $fileold = Import-Csv -Path "$path\Customers_old.csv" -Delimiter ","

    # Filtrowanie danych: usuwanie pustych i duplikatów
    $validate = $file | Where-Object { $_.first_name -ne $null -and $_.last_name -ne $null -and $_.email -ne "" } |
                Sort-Object -Property * -Unique

    # Porównanie z plikiem Customers_old.csv
    $final = $validate | Where-Object {
        -not ($fileold | Where-Object { $_.first_name -eq $_.first_name -and $_.last_name -eq $_.last_name -and $_.email -eq $_.email -and $_.lat -eq $_.lat -and $_.long -eq $_.long })
    }

    # Zapis przetworzonych danych
    if ($final.Count -eq 0) {
        error "Brak poprawnych danych po walidacji"
    } else {
        $final | Export-Csv -Path "$path\Customers_final.csv" -NoTypeInformation -Delimiter ","
    }
} catch {
    error "Błąd podczas walidacji danych"
}

# Zadanie 1d: Tworzenie tabeli CUSTOMERS_410509 w bazie danych PostgreSQL
try {
    log "Tworzenie tabeli CUSTOMERS_410509"
    C:\PostgreSQL\bin\16\psql.exe -h "localhost" -U "postgres" -d "skrypt" -c "CREATE TABLE IF NOT EXISTS CUSTOMERS_410509 (
        first_name varchar(50),
        last_name varchar(50),
        email varchar(50),
        lat float,
        long float,
        geoloc GEOGRAPHY(POINT, 4326)
    );"
} catch {
    error "Błąd podczas tworzenia tabeli"
}

# Zadanie 1e: Import danych do tabeli i aktualizacja geoloc
try {
    # Import danych do tabeli
    log "Import danych do tabeli"
    C:\PostgreSQL\bin\16\psql.exe -h "localhost" -U "postgres" -d "skrypt" -c "COPY CUSTOMERS_410509(first_name, last_name, email, lat, long) FROM '$path\Customers_final.csv' WITH DELIMITER ',' CSV HEADER;"

    # Aktualizacja kolumny geoloc
    C:\PostgreSQL\bin\16\psql.exe -h "localhost" -U "postgres" -d "skrypt" -c "UPDATE CUSTOMERS_410509 SET geoloc = ST_SetSRID(ST_MakePoint(long, lat), 4326);"
} catch {
    error "Błąd podczas importu danych"
}

# Zadanie 1f: Przenoszenie przetworzonego pliku do folderu PROCESSED
try {
    log "Przenoszenie pliku przetworzonego"
    Move-Item -Path "$path\Customers_final.csv" -Destination "$path/${timestamp}_Customers_final.csv"
} catch {
    error "Błąd podczas przenoszenia pliku"
}

# Zadanie 1h: Tworzenie tabeli BEST_CUSTOMERS_410509 z klientami w promieniu 50 km
try {
    log "Tworzenie tabeli BEST_CUSTOMERS_410509"
    C:\PostgreSQL\bin\16\psql.exe -h "localhost" -U "postgres" -d "skrypt" -c "
    CREATE TABLE IF NOT EXISTS BEST_CUSTOMERS_410509 AS 
    SELECT first_name, last_name 
    FROM CUSTOMERS_410509
    WHERE ST_Distance(
        geoloc, 
        ST_SetSRID(ST_MakePoint(-75.67329768604034, 41.39988501005976), 4326)::geography
    ) <= 50000;"
} catch {
    error "Błąd podczas tworzenia tabeli BEST_CUSTOMERS_410509"
}
