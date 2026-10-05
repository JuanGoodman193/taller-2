package com.pulsepass.domain;

public enum TicketStatus {

    /**
     * Reservado para una versión futura con pasarela de pagos (PRD sección 27).
     */
    RESERVED,

    PAID,

    USED,

    CANCELLED
}
