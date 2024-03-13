package com.example.inclusion.emoji;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class EmojiApplicationService {

    private final EmojiRepository emojiRepository;

    public EmojiApplicationService(EmojiRepository emojiRepository) {
        this.emojiRepository = emojiRepository;
    }

    public List<Emoji> fetchEmojis() {
        return emojiRepository.findAll();
    }

    public void addRandomEmoji() {
        emojiRepository.save(Emoji.random());
    }
}
