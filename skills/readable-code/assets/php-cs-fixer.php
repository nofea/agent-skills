<?php

// Copy to .php-cs-fixer.dist.php
$finder = PhpCsFixer\Finder::create()->in(__DIR__);

return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS' => true,
        'braces_position' => [
            'classes_opening_brace' => 'next_line_unless_newline_at_signature_end',
            'functions_opening_brace' => 'next_line_unless_newline_at_signature_end',
            'control_structures_opening_brace' => 'next_line_unless_newline_at_signature_end',
        ],
        'control_structure_continuation_position' => ['position' => 'next_line'],
        'control_structure_braces' => true,
    ])
    ->setFinder($finder);
