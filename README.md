####general assumptions
Anyone directly interacting with the system is represented by either an account key or contract.
  * Representation via contract allows for arbitrarily complex logic to be involved in taking actions through it.
    * A simple case would be requiring multiple signatures from within the represented organization.
Any tasks which don't notably benefit from an irrefutable public record are better suited to implementation within programs other than the contracts themselves.
  * This keeps the contracts cheap to operate and affords significantly more flexibility in later changes to how the overall system functions.
  * A major case would be interfaces that filter stewards to only display those that meet the requirements for official recognition.
It is significantly easier and cheaper to control which content is visible in interfaces to contracts than to limit what content can be added to the contracts
