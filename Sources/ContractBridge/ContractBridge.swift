public struct ContractBridge {
    public init() {
    }
    /// This enum is used by string interpolation of various classes such as Suit, Card, and Rank to
    /// determine the style of output.  Symbol will result in the shortest description, using symbols
    /// where appropriate, such as A♣ for the ace of clubs.
    public enum Style {
        case symbol, character, name
    }
}
