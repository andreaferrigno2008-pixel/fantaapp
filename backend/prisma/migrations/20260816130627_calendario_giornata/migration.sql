-- CreateTable
CREATE TABLE "CalendarioGiornata" (
    "id" TEXT NOT NULL,
    "stagione" TEXT NOT NULL,
    "giornata" INTEGER NOT NULL,
    "avversario" TEXT NOT NULL,

    CONSTRAINT "CalendarioGiornata_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CalendarioGiornata_stagione_giornata_key" ON "CalendarioGiornata"("stagione", "giornata");
