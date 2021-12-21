using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character : MonoBehaviour
{
    public enum SKILL {
        ATK1 = 1,
        ATK2 = 2,
    };

    public float speed = 5.0f;
    private Vector3 start;
    private Vector3 target;
    private float elapsed;
    private float need;
    private Animator animator;
    private void Awake()
    {
        start = transform.position;
        target = transform.position;
        animator = GetComponent<Animator>();
    }
    public void SetTarget(Vector3 target)
    {
        this.target = target;
        this.start =  transform.position;
        Vector3 towards = this.target - this.start;
        Debug.Log("SetTarget:" + towards.magnitude);
        elapsed = 0.0f;
        need = towards.magnitude / speed;
        var rotation = Quaternion.LookRotation(towards).eulerAngles;
        transform.rotation = Quaternion.Euler(0, rotation.y, 0);
        animator.SetInteger("Run", 1);
    }

    public void PlaySkill(SKILL s)
    {
        switch (s) {
        case SKILL.ATK1:
            animator.SetTrigger("ATK1");
            break;
        case SKILL.ATK2:
            animator.SetTrigger("ATK2");
            break;
        }
    }

    // Update is called once per frame
    void LateUpdate()
    {
        if (elapsed < need) {
            elapsed += Time.deltaTime;
            if (elapsed > need)
                elapsed = need;
            transform.position = Vector3.Lerp(start, target, elapsed / need);
        } else { 
            if (animator != null)
                animator.SetInteger("Run", 0);
        }
    }
}
