-- CreateTable
CREATE TABLE "Team" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "sigla" TEXT NOT NULL,
    "logoUrl" TEXT,

    CONSTRAINT "Team_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Player" (
    "id" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "teamId" TEXT NOT NULL,
    "ruoloClassic" TEXT NOT NULL,
    "ruoliMantra" TEXT,
    "quotazioneIniziale" INTEGER NOT NULL,
    "quotazioneAttuale" INTEGER NOT NULL,
    "fvm" INTEGER,
    "stagione" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Player_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlayerQuotation" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "data" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "valore" INTEGER NOT NULL,

    CONSTRAINT "PlayerQuotation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MatchdayStat" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "giornata" INTEGER NOT NULL,
    "voto" DOUBLE PRECISION,
    "fantavoto" DOUBLE PRECISION,
    "gol" INTEGER NOT NULL DEFAULT 0,
    "assist" INTEGER NOT NULL DEFAULT 0,
    "ammonizioni" INTEGER NOT NULL DEFAULT 0,
    "espulsioni" INTEGER NOT NULL DEFAULT 0,
    "autogol" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "MatchdayStat_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DataSourceRun" (
    "id" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "finishedAt" TIMESTAMP(3),
    "status" TEXT NOT NULL,
    "errorMessage" TEXT,
    "recordsCount" INTEGER,

    CONSTRAINT "DataSourceRun_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Asta" (
    "id" TEXT NOT NULL,
    "stagione" TEXT NOT NULL,
    "budgetTotale" INTEGER NOT NULL,
    "slotP" INTEGER NOT NULL DEFAULT 3,
    "slotD" INTEGER NOT NULL DEFAULT 8,
    "slotC" INTEGER NOT NULL DEFAULT 8,
    "slotA" INTEGER NOT NULL DEFAULT 6,
    "stato" TEXT NOT NULL DEFAULT 'in_corso',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Asta_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AstaPartecipante" (
    "id" TEXT NOT NULL,
    "astaId" TEXT NOT NULL,
    "nome" TEXT NOT NULL,
    "sonIo" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "AstaPartecipante_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AstaPick" (
    "id" TEXT NOT NULL,
    "astaId" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "partecipanteId" TEXT NOT NULL,
    "prezzo" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AstaPick_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RosaGiocatore" (
    "id" TEXT NOT NULL,
    "playerId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RosaGiocatore_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Team_nome_key" ON "Team"("nome");

-- CreateIndex
CREATE INDEX "Player_ruoloClassic_idx" ON "Player"("ruoloClassic");

-- CreateIndex
CREATE INDEX "Player_teamId_idx" ON "Player"("teamId");

-- CreateIndex
CREATE UNIQUE INDEX "Player_nome_teamId_stagione_key" ON "Player"("nome", "teamId", "stagione");

-- CreateIndex
CREATE INDEX "PlayerQuotation_playerId_data_idx" ON "PlayerQuotation"("playerId", "data");

-- CreateIndex
CREATE INDEX "MatchdayStat_giornata_idx" ON "MatchdayStat"("giornata");

-- CreateIndex
CREATE UNIQUE INDEX "MatchdayStat_playerId_giornata_key" ON "MatchdayStat"("playerId", "giornata");

-- CreateIndex
CREATE INDEX "DataSourceRun_source_startedAt_idx" ON "DataSourceRun"("source", "startedAt");

-- CreateIndex
CREATE UNIQUE INDEX "AstaPartecipante_astaId_nome_key" ON "AstaPartecipante"("astaId", "nome");

-- CreateIndex
CREATE INDEX "AstaPick_astaId_partecipanteId_idx" ON "AstaPick"("astaId", "partecipanteId");

-- CreateIndex
CREATE UNIQUE INDEX "AstaPick_astaId_playerId_key" ON "AstaPick"("astaId", "playerId");

-- CreateIndex
CREATE UNIQUE INDEX "RosaGiocatore_playerId_key" ON "RosaGiocatore"("playerId");

-- AddForeignKey
ALTER TABLE "Player" ADD CONSTRAINT "Player_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerQuotation" ADD CONSTRAINT "PlayerQuotation_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MatchdayStat" ADD CONSTRAINT "MatchdayStat_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AstaPartecipante" ADD CONSTRAINT "AstaPartecipante_astaId_fkey" FOREIGN KEY ("astaId") REFERENCES "Asta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AstaPick" ADD CONSTRAINT "AstaPick_astaId_fkey" FOREIGN KEY ("astaId") REFERENCES "Asta"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AstaPick" ADD CONSTRAINT "AstaPick_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AstaPick" ADD CONSTRAINT "AstaPick_partecipanteId_fkey" FOREIGN KEY ("partecipanteId") REFERENCES "AstaPartecipante"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RosaGiocatore" ADD CONSTRAINT "RosaGiocatore_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
