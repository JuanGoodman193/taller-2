package com.pulsepass.repository;

import com.pulsepass.domain.Ticket;
import com.pulsepass.domain.TicketStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TicketRepository extends JpaRepository<Ticket, Long> {

    Optional<Ticket> findByTicketCode(String ticketCode);

    List<Ticket> findByUserEmailIgnoreCaseOrderByPurchaseDateDesc(String email);

    long countByEventEventCodeAndStatus(String eventCode, TicketStatus status);

    List<Ticket> findByEventEventCodeAndStatusOrderByPurchaseDateAsc(String eventCode, TicketStatus status);
}
