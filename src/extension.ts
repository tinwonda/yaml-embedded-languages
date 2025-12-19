import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext) {
    console.log('YAML SQL Highlighting extension is now active');

    // The TextMate grammar handles syntax highlighting declaratively
    // No runtime code is needed for basic highlighting functionality

    // Future enhancement: Add dynamic grammar regeneration when config changes
    // context.subscriptions.push(
    //     vscode.workspace.onDidChangeConfiguration(e => {
    //         if (e.affectsConfiguration('yamlSqlHighlight.keyPatterns')) {
    //             // Regenerate grammar and prompt reload
    //         }
    //     })
    // );
}

export function deactivate() {
    console.log('YAML SQL Highlighting extension is now deactivated');
}
