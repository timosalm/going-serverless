package com.example.inclusion;

import com.example.inclusion.emoji.EmojiApplicationService;
import com.example.inclusion.emoji.Emoji;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(InclusionResource.BASE_URI)
class InclusionResource {

    static final String BASE_URI = "/api/v1/emojis";

    private final EmojiApplicationService emojiApplicationService;

    InclusionResource(EmojiApplicationService emojiApplicationService) {
        this.emojiApplicationService = emojiApplicationService;
    }

    @GetMapping
    public ResponseEntity<List<String>> fetchEmojis() {
        return ResponseEntity.ok(emojiApplicationService.fetchEmojis()
                .stream().map(Emoji::getStringValue).collect(Collectors.toList()));
    }

    @PostMapping
    public ResponseEntity<Void> addRandomEmoji() {
        this.emojiApplicationService.addRandomEmoji();
        return ResponseEntity.noContent().build();
    }
}
