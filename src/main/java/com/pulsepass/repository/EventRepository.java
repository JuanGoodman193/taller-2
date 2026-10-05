package com.pulsepass.repository;

import com.pulsepass.domain.Event;
import com.pulsepass.domain.EventStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EventRepository extends JpaRepository<Event, Long> {

    Optional<Event> findByEventCode(String eventCode);

    boolean existsByEventCode(String eventCode);

    List<Event> findByStatusOrderByEventDateAsc(EventStatus status);

    @Query("""
        SELECT DISTINCT e
        FROM Event e
        JOIN e.artists a
        WHERE LOWER(a.stageName) = LOWER(:stageName)
        ORDER BY e.eventDate ASC
        """)
    List<Event> findByArtistStageName(@Param("stageName") String stageName);
}
